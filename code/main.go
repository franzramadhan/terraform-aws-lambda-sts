package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/credentials/stscreds"
	"github.com/aws/aws-sdk-go/aws/session"
)

var errorLogger = log.New(os.Stderr, "ERROR ", log.Llongfile)

type Credential struct {
	AccessKeyId     string    `json:"access_key_id"`
	SecretAccessKey string    `json:"secret_access_key"`
	SessionToken    string    `json:"session_token"`
	Expiry          time.Time `json:"expire_at"`
	ProviderName    string    `json:"provider_name"`
}

func serverError(err error, message string) (events.APIGatewayProxyResponse, error) {
	errorLogger.Println(err.Error())

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       string(message),
	}, nil
}

func serveRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var errMsg error
	roleARN := os.Getenv("ASSUMED_ROLE_ARN")
	sess := session.Must(session.NewSession())
	conf := aws.Config{}
	if roleARN != "" {
		var creds *credentials.Credentials
		creds = stscreds.NewCredentials(sess, roleARN, func(p *stscreds.AssumeRoleProvider) {})
		conf.Credentials = creds
	} else {
		return serverError(errMsg, "Assumed role ARN is not set")
	}

	creds, err := conf.Credentials.Get()
	if err != nil {
		return serverError(err, "Unable to get credential")
	}

	exp, err := conf.Credentials.ExpiresAt()

	if err != nil {
		return serverError(err, "Unable to get credential expiry time")
	}

	cr := &Credential{
		AccessKeyId:     creds.AccessKeyID,
		SecretAccessKey: creds.SecretAccessKey,
		SessionToken:    creds.SessionToken,
		Expiry:          exp,
		ProviderName:    creds.ProviderName,
	}

	response, err := json.Marshal(cr)

	if err != nil {
		return serverError(err, "Unable to marshall credential")
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       string(response),
	}, nil
}

func main() {
	lambda.Start(serveRequest)
}

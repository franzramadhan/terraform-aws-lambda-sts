package main

import (
	"encoding/json"
	"errors"
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

type request struct {
	AssumedRoleARN string `json:"assumed_role_arn"`
	TokenDuration  int64  `json:"token_duration"`
	ExpiryWindow   int64  `json:"expiry_window"`
}

type Credential struct {
	AccessKeyId     string    `json:"AWS_ACCESS_KEY_ID"`
	SecretAccessKey string    `json:"AWS_SECRET_ACCESS_KEY"`
	SessionToken    string    `json:"AWS_SESSION_TOKEN"`
	Expiry          time.Time `json:"AWS_SESSION_TOKEN_EXPIRES_AT"`
}

func clientError(status int) (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode: status,
		Body:       http.StatusText(status),
	}, nil
}

func serverError(err error, message string) (events.APIGatewayProxyResponse, error) {
	errorLogger.Println(err.Error())

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       string(message),
	}, nil
}

func serveRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if req.HTTPMethod != "POST" {
		return clientError(http.StatusMethodNotAllowed)
	}

	if req.Headers["Content-Type"] != "application/json" {
		return clientError(http.StatusNotAcceptable)
	}
	que := new(request)
	err := json.Unmarshal([]byte(req.Body), que)
	if err != nil {
		return clientError(http.StatusUnprocessableEntity)
	}

	roleARN := que.AssumedRoleARN
	tokenDuration := que.TokenDuration
	expiryWindow := que.ExpiryWindow

	sess := session.Must(session.NewSession())
	conf := aws.Config{}

	if tokenDuration == 0 {
		tokenDuration = 3600
	}

	if roleARN != "" {
		var creds *credentials.Credentials
		creds = stscreds.NewCredentials(sess, roleARN, func(p *stscreds.AssumeRoleProvider) {
			p.Duration = time.Duration(tokenDuration) * time.Second
			p.ExpiryWindow = time.Duration(expiryWindow)
		})
		conf.Credentials = creds
	} else {
		return serverError(errors.New("Assumed role ARN is not set"), "Assumed role ARN is not set")
	}

	creds, err := conf.Credentials.Get()
	if err != nil {
		return serverError(err, "Unable to get credentials")
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

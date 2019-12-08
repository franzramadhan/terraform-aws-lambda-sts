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
var infoLogger = log.New(os.Stdout, "INFO ", log.Llongfile)

type request struct {
	AssumedRoleARN string `json:"assumed_role_arn"`
	TokenDuration  int64  `json:"token_duration"`
	ExpiryWindow   int64  `json:"expiry_window"`
	PrivateIP      string `json:"private_ip"`
	Hostname       string `json:"hostname"`
}

type Credential struct {
	Version         int       `json:"Version"`
	AccessKeyId     string    `json:"AccessKeyId"`
	SecretAccessKey string    `json:"SecretAccessKey"`
	SessionToken    string    `json:"SessionToken"`
	Expiration      time.Time `json:"Expiration"`
}

func respError(status int, message string) (events.APIGatewayProxyResponse, error) {
	errorLogger.Println(errors.New(message))

	return events.APIGatewayProxyResponse{
		StatusCode: status,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       string(message),
	}, nil
}

func serveRequest(req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if req.HTTPMethod != "POST" {
		return respError(http.StatusMethodNotAllowed, "HTTP method is not allowed.")
	}

	que := new(request)
	err := json.Unmarshal([]byte(req.Body), que)
	if err != nil {
		return respError(http.StatusUnprocessableEntity, "Cannot parse request.")
	}

	roleARN := que.AssumedRoleARN
	tokenDuration := que.TokenDuration
	expiryWindow := que.ExpiryWindow
	clientPrivateIP := que.PrivateIP
	clientHostname := que.Hostname

	sess := session.Must(session.NewSession())
	conf := aws.Config{}

	if tokenDuration == 0 {
		tokenDuration = 3600
	}

	if clientHostname == "" || clientPrivateIP == "" {
		clientHostname = "N/A"
		clientPrivateIP = "N/A"
	}

	if roleARN != "" {
		var creds *credentials.Credentials
		creds = stscreds.NewCredentials(sess, roleARN, func(p *stscreds.AssumeRoleProvider) {
			p.Duration = time.Duration(tokenDuration) * time.Second
			p.ExpiryWindow = time.Duration(expiryWindow) * time.Second
		})
		conf.Credentials = creds
	} else {
		return respError(http.StatusBadRequest, "Assumed role ARN is not set.")
	}

	creds, err := conf.Credentials.Get()
	if err != nil {
		return respError(http.StatusInternalServerError, "Unable to get credentials.")
	}

	exp, err := conf.Credentials.ExpiresAt()

	if err != nil {
		return respError(http.StatusInternalServerError, "Unable to get expiration time.")
	}

	cr := &Credential{
		Version:         1,
		AccessKeyId:     creds.AccessKeyID,
		SecretAccessKey: creds.SecretAccessKey,
		SessionToken:    creds.SessionToken,
		Expiration:      exp,
	}

	response, err := json.Marshal(cr)

	if err != nil {
		return respError(http.StatusInternalServerError, "Unable to marshall credentials.")
	}

	infoLogger.Printf("Hostname: %s, Private IP: %s, Public IP : %s - retrieved %s credential from assumed role ARN %s", clientHostname, clientPrivateIP, req.RequestContext.Identity.SourceIP, creds.AccessKeyID, roleARN)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"Content-Type": "application/json"},
		Body:       string(response),
	}, nil
}

func main() {
	lambda.Start(serveRequest)
}

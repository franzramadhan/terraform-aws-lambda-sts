# How To Test

Adjust input variables

## Manually

```
- terraform init
- terraform plan
- terraform apply
- terraform destroy
```

## With terratest

```
- cd ../../tests
- go test -v -count 1 -run TestCustomDomain
```

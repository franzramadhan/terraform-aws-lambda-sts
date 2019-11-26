# How To Test

## Manually

```
- Change required variables
- terraform init
- terraform plan
- terraform apply
- terraform destroy
```

## With terratest

```
- cd ../../tests
- go test -v -count 1 -run TestDefault
```

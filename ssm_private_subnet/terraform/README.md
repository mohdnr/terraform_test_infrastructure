# Requirements
- AWS CLI
- [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

# Connect to ECS task
`aws ssm start-session --target ecs:<CLUSTER>_<TASK ID>_<CONTAINER_RUNTIME_ID> --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["80"], "localPortNumber":["1338"]}' --region ca-central-1`

Example
```bash
aws ssm start-session --target ecs:internal_ad87713568a9469b8bb056780a2e1ffd_ad87713568a9469b8bb056780a2e1ffd-3386804179 --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["80"], "localPortNumber":["1338"]}' --region ca-central-1```
project_id = "{PROJECT_ID}"

app_name = "ci-cd"

region = "{REGION}"

private_worker_pool_id = "{REPLACE_WITH_WORKER_POOL_ID}"

network_name = "{REPLACE_WITH_NETWORK_NAME}"

gitlab_auth = {
  authorizer_credential_secret_id      = "REPLACE_WITH_READ_API_SECRET_ID"
  read_authorizer_credential_secret_id = "REPLACE_WITH_READ_USER_SECRET_ID"
  webhook_secret_id                    = "REPLACE_WITH_WEBHOOK_SECRET_ID"
  secret_project_id                    = "REPLACE_WITH_SECRET_PROJECT_ID"

  # If you are using a self-hosted instance, you may change the URL below accordingly
  enterprise_host_uri = "https://gitlab.com"
  # Format is projects/PROJECT/locations/LOCATION/namespaces/NAMESPACE/services/SERVICE
  enterprise_service_directory = "REPLACE_WITH_SERVICE_DIRECTORY"
  # .pem string
  enterprise_ca_certificate = <<EOF
REPLACE_WITH_SSL_CERT
EOF
}

ci_repository = {
  repository_name = "secure-ci"
  repository_url  = "https://gitlab.com/user/secure-ci.git"
}

cd_repository = {
  repository_name = "secure-cd"
  repository_url  = "https://gitlab.com/user/secure-cd.git"
}

access_level_name = "{ACCESS_LEVEL_NAME}"

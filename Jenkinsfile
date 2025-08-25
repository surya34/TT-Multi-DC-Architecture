pipeline {
  agent { label 'linux' }  // your agent label
  environment {
    VAULT_ADDR = 'http://vault:8200'
    ROLE_ID    = credentials('vault-role-id')
    WRAP_TOKEN = credentials('vault-wrap-token') // or use SECRET_ID = credentials('vault-secret-id')
  }
  stages {
    stage('Vault: Login via AppRole') {
      steps {
        sh '''
          set -euo pipefail

          echo "Unwrapping SecretID..."
          SECRET_ID=$(curl -s \
            --header "X-Vault-Token: $WRAP_TOKEN" \
            $VAULT_ADDR/v1/sys/wrapping/unwrap | jq -r .data.secret_id)

          echo "Logging into Vault with AppRole..."
          VAULT_TOKEN=$(curl -s --request POST $VAULT_ADDR/v1/auth/approle/login \
            --data "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" | jq -r .auth.client_token)

          # Save token to a workspace-local file and mask in logs
          echo "VAULT_TOKEN=${VAULT_TOKEN}" > .vault_env
          chmod 600 .vault_env
        '''
      }
    }

    stage('Vault: Read KV smoke test') {
      steps {
        sh '''
          set -euo pipefail
          source ./.vault_env

          echo "Reading kv/hello..."
          curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
            "$VAULT_ADDR/v1/kv/data/hello" | jq -r '.data.data'
        '''
      }
    }
  }
  post {
    always {
      sh 'rm -f .vault_env || true'
    }
  }
}


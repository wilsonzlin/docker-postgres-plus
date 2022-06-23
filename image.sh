export POSTGRES_PLUS_IMAGE_NAME=wilsonzlin/postgres-plus
export POSTGRES_PLUS_IMAGE_TAG=$POSTGRES_PLUS_IMAGE_NAME:$(jq -r .pg ./versions.json)-$(jq -r .rum ./versions.json)-$(jq -r .ts ./versions.json)-$(jq -r .vector ./versions.json)

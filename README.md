# Cleaning Amazon Glacier vault

Need to delete AWS Glacier **vault**.

**Would take ~2 days**: 1st day for initiate job for retrieve inventory info, 2nd day for **archive** deletion.

*Note: also check comments inside script.*

## 1. Manual part: get JSON inventory file with all archives inside vault (need their IDs)

```bash
aws glacier list-vaults --account-id "$AWS_ACCOUNT_ID"

aws glacier initiate-job    --account-id "$AWS_ACCOUNT_ID" \
                            --vault-name "$AWS_GLACIER_VAULT_NAME" \
                            --job-parameters '{"Type": "inventory-retrieval"}'
###########################################################
# After 1 day or so, continue (last time it took 6 hours) #
###########################################################

# Check job status
aws glacier list-jobs   --account-id "$AWS_ACCOUNT_ID" \
                        --vault-name "$AWS_GLACIER_VAULT_NAME"

# If "Completed": true AND "StatusCode": "Succeeded", get data from job as file with JSON
aws glacier get-job-output  --account-id $AWS_ACCOUNT_ID \
                            --vault-name "$AWS_GLACIER_VAULT_NAME" \
                            --job-id "$JOB_ID" \ "$AWS_GLACIER_VAULT_INVENTORY_JOB_OUTPUT_JSON_FILENAME"
```

## 2. Automated part: delete archives one-by-one with shell script

```bash
# Change variables inside script
nano aws_glacier_clean.sh

# Run script for INITIATING deletion all archives
./aws_glacier_clean.sh
```

## 3. Manual part: check that vault is empty now and delete vault

```bash
###############################
# After 1 day or so, continue #
###############################

aws glacier describe-vault  --account-id "$AWS_ACCOUNT_ID" \
                            --vault-name "$AWS_GLACIER_VAULT_NAME"

# Should be --> "NumberOfArchives": 0

aws glacier delete-vault    --account-id "$AWS_ACCOUNT_ID" \
                    --vault-name "$AWS_GLACIER_VAULT_NAME"

# Last check that there is no more that vault
aws glacier list-vaults --account-id "$AWS_ACCOUNT_ID"
```

## Other

How to pretty-print JSON in a shell:

```bash
cat filename.json | python3 -m json.tool
```

## Links

[aws cli docs](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/glacier/index.html)

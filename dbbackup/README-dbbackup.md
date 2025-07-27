# What it does ?

Docker container that runs in k8s to make backup of moinmoin to AWS s3

## AWS policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListBucketWithPrefix",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::backups.vigor.nz",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "moinmoin/*",
                        "moinmoin",
                        "testrun/*",
                        "testrun"
                    ]
                }
            }
        },
        {
            "Sid": "ObjectLevelActions",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:ListTagsForResource",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::backups.vigor.nz/moinmoin/*",
                "arn:aws:s3:::backups.vigor.nz/testrun/*"
            ]
        }
    ]
}
```

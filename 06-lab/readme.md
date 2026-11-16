# Lab: Deploy a Static Website with Amazon S3 and CloudFront

In this lab, you will upload an HTML file to Amazon S3. Then you will use Amazon CloudFront to publish the website. The S3 bucket will stay private.

## Learning goals

After this lab, you can:

- Explain what S3, CloudFront, and Origin Access Control (OAC) do.
- Upload a static HTML file to a private S3 bucket.
- Create a CloudFront distribution.
- Let CloudFront read the S3 file through OAC.
- Set a default root object.
- Find and fix common **403 Access Denied** errors.
- Update the website and clear the CloudFront cache.

## Time

45 to 60 minutes

## Architecture

~~~text
Browser
   |
   | HTTPS
   v
CloudFront
   |
   | Signed request through OAC
   v
Private S3 bucket
   |
   `-- ai-academy.html
~~~

## What you need

- An AWS account for the class
- Access to Amazon S3 and Amazon CloudFront
- A web browser
- Git
- The GitHub repository from your teacher

## Repository structure

~~~text
ai-academy-cloudfront-lab/
├── README.md
└── website/
    └── ai-academy.html
~~~

## Part 1: Get the files from GitHub

Clone the repository:

~~~bash
git clone <REPOSITORY_URL>
cd <REPOSITORY_NAME>
~~~

Check that this file exists:

~~~text
website/ai-academy.html
~~~

Open the file in a browser. Make sure the page works on your computer.

## Part 2: Create an S3 bucket

1. Open the AWS Management Console.
2. Go to **Amazon S3**.
3. Choose **Create bucket**.
4. Enter a unique bucket name. For example:

   ~~~text
   ai-academy-<student-id>
   ~~~

5. Select the AWS Region from your teacher.
6. Keep **Block all public access** on.
7. Choose **Create bucket**.

> Do not turn on S3 Static Website Hosting. CloudFront will use the S3 bucket as an origin.

## Part 3: Upload the website

1. Open your new bucket.
2. Choose **Upload**.
3. Upload **website/ai-academy.html**.
4. Check the object name.

The object must be at the root of the bucket:

~~~text
ai-academy.html
~~~

S3 object names use uppercase and lowercase letters as different characters. Check the spelling carefully.

## Part 4: Create a CloudFront distribution

1. Open **Amazon CloudFront**.
2. Choose **Create distribution**.
3. Select your S3 bucket as the origin.
4. Select **Origin access control settings**.
5. Create a new OAC, or use the OAC from your teacher.
6. Set the OAC to **Sign requests**.
7. Set **Viewer protocol policy** to:

   ~~~text
   Redirect HTTP to HTTPS
   ~~~

8. Set **Default root object** to:

   ~~~text
   ai-academy.html
   ~~~

9. Choose **Create distribution**.
10. Let AWS update the S3 bucket policy. If AWS gives you a policy, copy it to the bucket policy.

> Do not add / before the default root object. The value /ai-academy.html can cause a **403 Access Denied** error.

## Part 5: Check the bucket policy

The bucket policy must let your CloudFront distribution read the files through OAC.

The policy looks like this:

~~~json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::BUCKET_NAME/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
        }
      }
    }
  ]
}
~~~

Check these values:

- **BUCKET_NAME** is your S3 bucket name.
- **ACCOUNT_ID** is your AWS account ID.
- **DISTRIBUTION_ID** is your CloudFront distribution ID.

## Part 6: Test the website

Wait until the CloudFront status is **Deployed**.

Open the main website URL:

~~~text
https://<DISTRIBUTION_DOMAIN>/
~~~

Then open the file URL:

~~~text
https://<DISTRIBUTION_DOMAIN>/ai-academy.html
~~~

Both URLs should show the same page. The browser should use HTTPS.

## Part 7: Update the website

1. Open **website/ai-academy.html**.
2. Add your group name. For example:

   ~~~html
   <p>Deployed by Group 01</p>
   ~~~

3. Upload the file to S3 again.
4. Replace the old object.
5. Refresh the CloudFront website.

You may still see the old page. CloudFront may have a cached copy.

## Part 8: Clear the CloudFront cache

1. Open your CloudFront distribution.
2. Open the **Invalidations** tab.
3. Choose **Create invalidation**.
4. Enter this object path:

   ~~~text
   /*
   ~~~

5. Create the invalidation.
6. Wait until its status is **Completed**.
7. Open the website again.

You should now see your new group name.

## Troubleshooting

### The file URL works, but / shows Access Denied

This URL does not work:

~~~text
https://<DISTRIBUTION_DOMAIN>/
~~~

This URL works:

~~~text
https://<DISTRIBUTION_DOMAIN>/ai-academy.html
~~~

Check the default root object. It must be:

~~~text
ai-academy.html
~~~

Do not add / before the file name.

### All URLs show Access Denied

Check these settings:

- CloudFront uses the correct S3 bucket.
- The origin uses OAC.
- OAC signs the requests.
- The bucket policy allows **s3:GetObject**.
- **AWS:SourceArn** has the correct account ID and distribution ID.
- The file name in S3 matches the URL.

### The website still shows the old page

- Make sure you replaced the old S3 object.
- Create a CloudFront invalidation.
- Try a private or incognito browser window.

## Challenge

Choose at least one task:

1. Change the colors and text on the website.
2. Add an **about.html** page.
3. Add a custom error page for a missing file.
4. Upload the file with the AWS CLI.

## What to submit

Submit these items:

1. Your CloudFront URL
2. A screenshot of the website
3. A screenshot of the S3 object
4. A screenshot of the CloudFront origin and default root object
5. Short answers to these questions:
   - What does CloudFront do?
   - What does OAC do?
   - What is a default root object?
   - Why can a website show an old file after an update?

## Score

| Item | Points |
|---|---:|
| The website works through CloudFront | 30 |
| The S3 bucket is private | 20 |
| OAC and the bucket policy are correct | 20 |
| The default root object works | 10 |
| The student updates the site and clears the cache | 10 |
| The student answers the questions | 10 |
| **Total** | **100** |

## Cleanup

After your teacher checks the lab:

1. Disable and delete the CloudFront distribution.
2. Delete all files in the S3 bucket.
3. Delete the S3 bucket.
4. Delete the OAC if you do not use it.

Cleanup helps you avoid extra AWS costs.

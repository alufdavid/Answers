# **Terraform Static Website Hosting with CloudFront on AWS**

This Terraform configuration sets up a static website hosted on AWS S3, served globally through CloudFront, and ensures secure access to the content using an Origin Access Identity (OAI). 

## **Prerequisites**

1. **AWS Account**: Ensure you have an AWS account and access to the required permissions.
2. **Terraform**: Install Terraform on your local machine. You can download it from [here](https://www.terraform.io/downloads.html).
3. **IAM Permissions**: The IAM identity (user or role) you use to run this Terraform configuration must have the following permissions:
   - `s3:CreateBucket`
   - `s3:PutBucketWebsite`
   - `s3:PutBucketPolicy`
   - `cloudfront:CreateDistribution`
   - `cloudfront:CreateCloudFrontOriginAccessIdentity`
   - `iam:CreatePolicy`
   - `iam:AttachUserPolicy`
   
   This ensures that the identity has enough permissions to create and configure S3 buckets, CloudFront distributions, and the necessary IAM policies.

## **Getting Started**

### 1. **Clone or Copy the Terraform Configuration**

Clone or copy the Terraform code into a directory on your local machine. Ensure you have the necessary IAM credentials (access key and secret key) to interact with AWS.

### 2. **Set Up AWS Provider Configuration**

Update the `provider "aws"` block with your AWS credentials and the desired region.

### 3. **Customize the S3 Bucket Name**

In the following resource, you need to set a globally unique name for your S3 bucket:

```hcl
resource "aws_s3_bucket" "website_bucket" {
  bucket = "your-unique-name-static-website-2024"  # Replace with a unique name
}
```

### 4. **Run Terraform Commands**

- Initialize Terraform to download the necessary provider plugins:

  ```bash
  terraform init
  ```

- Run `terraform plan` to see what changes will be made:

  ```bash
  terraform plan
  ```

- Apply the configuration to create the resources:

  ```bash
  terraform apply
  ```

   You’ll be prompted to confirm before Terraform applies the changes. Type `yes` to proceed.

### 5. **Access Your Website**

Once the configuration is applied, Terraform will output the CloudFront distribution domain name:

```hcl
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.website.domain_name
}
```

Use this URL to access your static website.

## **IAM Permissions for the Identity Running Terraform**

The IAM identity (whether a user or a role) that executes this Terraform configuration needs sufficient permissions to create resources in AWS, including the ability to:
- Create and manage S3 buckets.
- Configure static website hosting on S3.
- Set policies for the bucket.
- Create CloudFront distributions and associated resources like Origin Access Identity (OAI).
  
Here is an example of the permissions policy (in JSON) that grants the necessary access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketWebsite",
        "s3:PutBucketPolicy",
        "cloudfront:CreateDistribution",
        "cloudfront:CreateCloudFrontOriginAccessIdentity",
        "iam:CreatePolicy",
        "iam:AttachUserPolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Optional: Upload Custom Website Files**

The configuration includes a simple `index.html` file to upload to the S3 bucket. You can modify the `aws_s3_object.website_files` resource to upload additional files, such as CSS or JavaScript files, to the S3 bucket for your website.

Example:

```hcl
resource "aws_s3_object" "website_files" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "index.html"  # Path to your local HTML file
  content_type = "text/html"   # Specify the content type
}
```

### **Cleaning Up**

To remove the resources you created, use the `terraform destroy` command:

```bash
terraform destroy
```

This will prompt you for confirmation before deleting the resources.

## **Conclusion**

With this setup, your static website is hosted on S3, served globally through CloudFront, and configured to ensure secure access. The CloudFront OAI ensures that only CloudFront can access the content in the S3 bucket, making the website secure.

Feel free to modify and expand this configuration to fit your specific use case, such as adding SSL certificates, customizing cache behavior, or integrating with a domain name provider.


resource "aws_s3_bucket" "unops" {
  bucket = "${var.bucket_name}"
  acl    = "private"
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"
  path = "/managed/"

  assume_role_policy = <<EOF
  {
    "Version"  : "2012-10-17",
    "Statement": [
      {
        "Effect"   : "Allow",
        "Principal": {
          "Service": "codebuild.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild_policy"
  role = "${aws_iam_role.codebuild_role.id}"

  policy = <<EOF
  {
    "Version"  : "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/${var.service_name}_build",
          "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/${var.service_name}_build:*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        "Resource": "${aws_s3_bucket.unops.arn}/*"
      }
    ]
  }
  EOF
}

resource "aws_codebuild_project" "unops_build" {
  name          = "unops-build"
  service_role  = "${aws_iam_role.build_service_role}"
  badge_enabled = true

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/${var.image}"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "BUILD_OUTPUT_BUCKET"
      "value" = "${aws_s3_bucket.unops.bucket}"
    }

    environment_variable {
      "name"  = "BUILD_VPC_ID"
      "value" = "${var.vpc_id}"
    }

    environment_variable {
      "name"  = "BUILD_SUBNET_ID"
      "value" = "${var.subnet_id}"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline_role"
  path = "/managed/"

  assume_role_policy = <<EOF
  {
    "Version"  : "2012-10-17",
    "Statement": [
      {
        "Effect"   : "Allow",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
  {
    "Version"  : "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ],
        "Resource": [
          "${aws_s3_bucket.unops.bucket}",
          "${aws_s3_bucket.unops.bucket}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchGetBuilds"
        ],
        "Resource": "${aws_codebuild_project.unops.arn}"
      }
    ]
  }
  EOF
}

resource "aws_codepipeline" "unops_pipeline" {
  name     = "unops-pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.unops.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["SourceZip"]

      configuration {
        Owner  = "${var.organization}"
        Repo   = "${var.repo}"
        Branch = "${var.branch}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceZip"]
      version          = "1"
      output_artifacts = "BuiltZip"

      configuration {
        ProjectName = "${var.service_name}"
      }
    }
  }
}

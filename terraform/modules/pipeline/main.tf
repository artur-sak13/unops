resource "aws_s3_bucket" "unops" {
  bucket = "${var.bucket_name}"
  acl    = "private"
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role"
  path               = "/managed/"
  assume_role_policy = "${data.aws_iam_policy_document.codebuild_assume_role.json}"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "codebuild_permissions" {
  statement {
    sid    = "CodeBuildToCWL"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.service_name}_build",
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${var.service_name}_build:*",
    ]
  }

  statement {
    sid    = "CodeBuildToS3ArtifactRepo"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.unops.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "codebuild_policy"
  role   = "${aws_iam_role.codebuild_role.id}"
  policy = "${data.aws_iam_policy_document.codebuild_permissions.json}"
}

resource "aws_codebuild_project" "unops_build" {
  name         = "unops-build"
  service_role = "${aws_iam_role.codebuild_role.arn}"

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
      "name"  = "VPC_ID"
      "value" = "${var.vpc_id}"
    }

    environment_variable {
      "name"  = "SUBNET_ID"
      "value" = "${var.subnet_id}"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "codepipeline_role"
  path               = "/managed/"
  assume_role_policy = "${data.aws_iam_policy_document.codepipeline_assume_role.json}"
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = "${aws_iam_role.codepipeline_role.id}"
  policy = "${data.aws_iam_policy_document.codepipeline_permissions.json}"
}

data "aws_iam_policy_document" "codepipeline_permissions" {
  statement {
    sid    = "CodePipelinePassRoleAccess"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "${aws_iam_role.codebuild_role.arn}",
    ]
  }

  statement {
    sid    = "CodePipelineS3ArtifactAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.unops.arn}",
      "${aws_s3_bucket.unops.arn}/*",
    ]
  }

  statement {
    sid    = "CodePipelineBuildAccess"
    effect = "Allow"

    actions = [
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:BatchGetBuilds",
    ]

    resources = [
      "${aws_codebuild_project.unops_build.arn}",
    ]
  }
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
        Owner      = "${var.organization}"
        Repo       = "${var.repo}"
        Branch     = "${var.branch}"
        OAuthToken = "${var.github_token}"
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
      output_artifacts = ["BuiltZip"]

      configuration {
        ProjectName = "${var.service_name}"
      }
    }
  }
}

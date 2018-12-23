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
  name                  = "CodeBuildServiceRole"
  path                  = "/managed/"
  force_detach_policies = true
  assume_role_policy    = "${data.aws_iam_policy_document.codebuild_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "codebuild_cwl" {
  role       = "${aws_iam_role.codebuild_role.name}"
  policy_arn = "${aws_iam_policy.codebuild_to_cwl_policy.arn}"
}

resource "aws_iam_policy" "codebuild_to_cwl_policy" {
  name   = "CodeBuildToCWL"
  policy = "${data.aws_iam_policy_document.codebuild_to_cwl.json}"
}

data "aws_iam_policy_document" "codebuild_to_cwl" {
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
}

resource "aws_iam_role_policy_attachment" "codebuild_s3" {
  role       = "${aws_iam_role.codebuild_role.name}"
  policy_arn = "${aws_iam_policy.codebuild_to_s3_artifact_repo_policy.arn}"
}

resource "aws_iam_policy" "codebuild_to_s3_artifact_repo_policy" {
  name   = "CodeBuildToS3ArtifactRepo"
  policy = "${data.aws_iam_policy_document.codebuild_to_s3_artifact_repo.json}"
}

data "aws_iam_policy_document" "codebuild_to_s3_artifact_repo" {
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

resource "aws_iam_role" "codepipeline_role" {
  name                  = "PipelineExecutionRole"
  path                  = "/managed/"
  force_detach_policies = true
  assume_role_policy    = "${data.aws_iam_policy_document.codepipeline_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "codepipeline_pass" {
  role       = "${aws_iam_role.codepipeline_role.name}"
  policy_arn = "${aws_iam_policy.codepipeline_pass_role_access_policy.arn}"
}

resource "aws_iam_policy" "codepipeline_pass_role_access_policy" {
  name   = "CodePipelinePassRoleAccess"
  policy = "${data.aws_iam_policy_document.codepipeline_pass_role_access.json}"
}

data "aws_iam_policy_document" "codepipeline_pass_role_access" {
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
}

resource "aws_iam_role_policy_attachment" "codepipeline_s3" {
  role       = "${aws_iam_role.codepipeline_role.name}"
  policy_arn = "${aws_iam_policy.codepipeline_s3_artifact_access_policy.arn}"
}

resource "aws_iam_policy" "codepipeline_s3_artifact_access_policy" {
  name   = "CodePipelineS3ArtifactAccess"
  policy = "${data.aws_iam_policy_document.codepipeline_s3_artifact_access.json}"
}

data "aws_iam_policy_document" "codepipeline_s3_artifact_access" {
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
}

resource "aws_iam_role_policy_attachment" "codepipeline_codebuild" {
  role       = "${aws_iam_role.codepipeline_role.name}"
  policy_arn = "${aws_iam_policy.codepipeline_build_access_policy.arn}"
}

resource "aws_iam_policy" "codepipeline_build_access_policy" {
  name   = "CodePipelineBuildAccess"
  policy = "${data.aws_iam_policy_document.codepipeline_build_access.json}"
}

data "aws_iam_policy_document" "codepipeline_build_access" {
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
      output_artifacts = ["code"]

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
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["code"]
      output_artifacts = ["events"]

      configuration {
        ProjectName = "${aws_codebuild_project.unops_build.name}"
      }
    }
  }
}

data "aws_caller_identity" "current" {}

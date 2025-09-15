resource "aws_iam_user" "github" {
  name = var.github_iam_user_name

  tags = {
    Name = var.github_iam_user_name
  }
}

data "aws_iam_policy_document" "lb_ro" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_push_only" {
  name        = "ecr-push-only-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:ap-northeast-2:${data.aws_caller_identity.caller.account_id}:repository/${var.ecr_name}"
      }
    ]
  })
}


resource "aws_iam_user_policy_attachment" "attach_ecr_push" {
  user       = aws_iam_user.github.name
  policy_arn = aws_iam_policy.ecr_push_only.arn
}

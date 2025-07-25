resource "aws_security_group" "external_alb_sg" {
    name = "external alb sg"
}

resource "aws_security_group" "web_sg" {
    name = "web sg"
}

resource "aws_security_group" "internal_alb_sg" {
    name = "internal alb sg"
}

resource "aws_security_group" "was_sg" {
    name = "was sg"
}

resource "aws_eks_cluster" "olivesafety_cluster" {
    name = "olivesafety"

    access_config {
      authentication_mode = "API"
    }

    role_arn = ""
    version = "1.31"

    vpc_config {
      subnet_ids = [ 
        aws_subnet.olivesafety-sub-pub-01.id,
        aws_subnet.olivesafety-sub-pub-02.id,
        aws_subnet.olivesafety-sub-pri-01.id,
        aws_subnet.olivesafety-sub-pri-02.id,
        aws_subnet.olivesafety-sub-pri-03.id,
        aws_subnet.olivesafety-sub-pri-04.id
       ]
    }
}

resource "aws_eks_node_group" "app" {
    cluster_name = aws_eks_cluster.olivesafety_cluster.name
    node_group_name = "app"
    instance_types = "m5.large"
    node_role_arn = ""


    subnet_ids = [ 
      aws_subnet.olivesafety-sub-pri-01.id,
      aws_subnet.olivesafety-sub-pri-02.id,
      aws_subnet.olivesafety-sub-pri-03.id,
      aws_subnet.olivesafety-sub-pri-04.id
     ]

     scaling_config {
       desired_size = 2
       min_size = 2
       max_size = 2
     }

     update_config {
       max_unavailable = 1
     }

     depends_on = [ 

      ]
}

resource "aws_eks_node_group" "web" {
    cluster_name = aws_eks_cluster.olivesafety_cluster.name
    node_group_name = "web"
    instance_types = "t3.medium"
    node_role_arn = ""

    scaling_config {
      desired_size = 2
      min_size = 2
      max_size = 2
    }

    subnet_ids = [
      aws_subnet.olivesafety-sub-pri-01.id,
      aws_subnet.olivesafety-sub-pri-02.id,
      aws_subnet.olivesafety-sub-pri-03.id,
      aws_subnet.olivesafety-sub-pri-04.id
    ]

    update_config {
       max_unavailable = 1
     }
    
}

resource "aws_lb" "web_lb" {
    name = ""
    internal = false
    load_balancer_type = "application"
    subnets = [  
      
    ]
    security_groups = [

    ]
    ip_address_type = "ipv4"
    access_logs {
      enabled = false
      bucket = ""
      prefix = ""
    }
    idle_timeout = "60"
    enable_deletion_protection = "false"
    enable_http2 = "true"
    enable_cross_zone_load_balancing = "true"
}

resource "aws_lb_listener" "web_lb" {
    load_balancer_arn = "arn:aws:elasticloadbalancing:ap-northeast-1::loadbalancer/app/"
    port = 80
    protocol = "HTTP"

    default_action {
      fixed_response {
        content_type = "text/plain"
        status_code = "404"
      }
      type = "fixed-response"
    }
}

resource "aws_lb_target_group" "instance" {
    health_check {
      interval = 30
      path = "/"
      port = "traffic-port"
      protocol = "HTTP"
      timeout = 5
      unhealthy_threshold = 2
      healthy_threshold = 5
      matcher = "200"
    }
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = "${aws_vpc.olivesafety-vpc-ap-01.id}"
    name = "DR"
}

resource "aws_lb_target_group" "web_lb_tg" {
    health_check {
      interval = 15
      path = "/"
      port = "traffic-port"
      protocol = "HTTP"
      timeout = 5
      unhealthy_threshold = 2
      healthy_threshold = 2
      matcher = "200"
    }
    port = 8080
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = "${aws_vpc.olivesafety-vpc-ap-01.id}"
    name = "web_lb"
}
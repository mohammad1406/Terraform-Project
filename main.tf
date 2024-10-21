provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "me-central-1"
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "main_vpc" {
  vpc_name   = "main-vpc"
  cidr_block = "10.0.0.0/8"  
}

resource "alicloud_vswitch" "vswitch_subnet" {
  vpc_id     = alicloud_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"  
  zone_id    = data.alicloud_zones.default.zones.0.id
  vswitch_name = "vswitch-subnet"
}

resource "alicloud_security_group" "sg" {
  name   = "main-sg"
  description = "Allow ssh & http"
  vpc_id      = alicloud_vpc.main_vpc.id
}

# Allow incoming traffic on port 22 (SSH) and 80 (HTTP)
resource "alicloud_security_group_rule" "allow_inbound" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  security_group_id = alicloud_security_group.sg.id
  priority          = 1
  port_range        = "22/22"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  security_group_id = alicloud_security_group.sg.id
  priority          = 1
  port_range        = "80/80"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_ecs_key_pair" "no-key" {
  key_pair_name   = "project"  # Use a unique name to avoid conflict
  key_file        = "project.pem"
}


resource "alicloud_instance" "instance" {
  security_groups            = [alicloud_security_group.sg.id]
  instance_type              = "ecs.g6.large"
  instance_name              = "project"
  instance_charge_type       = "PostPaid"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 20
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  vswitch_id                 = alicloud_vswitch.vswitch_subnet.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByTraffic"
  key_name                   = alicloud_ecs_key_pair.no-key.key_pair_name
  user_data = base64encode(file("nginx.sh"))
}

output "public_ip" {
  value = alicloud_instance.instance.public_ip
}

output "instance_id" {
  value = alicloud_instance.instance.vpc_id
}
#output "DNS" {
#  value = alicloud_instance.instance.public_dns
#} 
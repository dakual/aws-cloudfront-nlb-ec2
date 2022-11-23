resource "aws_instance" "main" {
  count                       = length(local.public_subnets)

  ami                         = local.ami
  instance_type               = local.instance_type
  key_name                    = local.key_name
  vpc_security_group_ids      = [ aws_security_group.main.id ] 
  subnet_id                   = element(aws_subnet.public.*.id, count.index)
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "admin"
    private_key = file("~/.aws/pems/mykey.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./nginx.sh"
    destination = "/home/admin/nginx.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 777 ./nginx.sh",
      "./nginx.sh"
    ]
  }
}



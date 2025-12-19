output "cluster_id" {
  value = aws_eks_cluster.manisha_eks_cluster.id
}

output "node_group_id" {
  value = aws_eks_node_group.manisha_node_group.id
}

output "vpc_id" {
  value = aws_vpc.manisha_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.manisha_subnet[*].id
}

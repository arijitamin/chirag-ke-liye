resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "redis-subnet"
  subnet_ids = [aws_subnet.private_persistance.id]
}

resource "aws_elasticache_cluster" "medusa_redis" {
  cluster_id           = "medusa-redis"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7.1"
  engine_version       = "7.1.2"
  port                 = 6379
}

resource "aws_elasticache_replication_group" "medusa_redis_replication_group" {
  automatic_failover_enabled  = true
  preferred_cache_cluster_azs = ["ap-south-1a", "ap-south-1b"]
  replication_group_id        = "medusa_redis_replication_group"
  description                 = "medusa_redis_replication_group"
  node_type                   = "cache.m4.large"
  num_cache_clusters          = 2
  parameter_group_name        = "default.redis7.1"
  port                        = 6379

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}

resource "aws_elasticache_cluster" "replica" {
  cluster_id           = "${aws_elasticache_cluster.medusa_redis.id}"
  replication_group_id = aws_elasticache_replication_group.medusa_redis_replication_group.id
}
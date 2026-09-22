-- 批 BUG-003：nodes 表加 system_tag 列 + 清空数据（测试数据可删）
-- 归运维在 Supabase SQL Editor 跑
-- 本批不依赖服务端——跑了之后跨设备同步正常

ALTER TABLE nodes ADD COLUMN system_tag TEXT;

-- 清空 nodes（CASCADE 防外键约束挡 TRUNCATE）
TRUNCATE TABLE nodes CASCADE;
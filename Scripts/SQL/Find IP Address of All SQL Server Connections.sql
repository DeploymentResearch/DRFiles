SELECT	ecs.client_net_address, ecs.client_tcp_port, ess.[program_name], 
		ess.[host_name], ess.login_name,
		SUM(num_reads) TotalReads, SUM(num_writes) TotalWrites,
		COUNT(ecs.session_id) AS SessionCount
FROM sys.dm_exec_sessions AS ess WITH (NOLOCK) 
INNER JOIN sys.dm_exec_connections AS ecs WITH (NOLOCK) 
ON ess.session_id = ecs.session_id 
GROUP BY	ecs.client_net_address, ecs.client_tcp_port, ess.[program_name], 
		ess.[host_name], ess.login_name
ORDER BY SessionCount DESC;
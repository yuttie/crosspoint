<?php
$GROUP_NUM = 3;

// IPアドレスを取得して変数にセットする
$ipAddress = $_SERVER["REMOTE_ADDR"];
$fp = "../group_id/" . $ipAddress;

// IPアドレスを保存
if(!file_exists($fp)){
	$ip = substr(str_replace(".", "", $ipAddress), -2);
	$gid = ($ip % $GROUP_NUM) + 1;
	$handle = fopen($fp, "w");
	fwrite($handle, $gid);
	fclose($handle);
	//file_put_contents($fp, $gid | LOCK_EX);
 }

// master.htmlにIPアドレスを返す
$test = array(
	"ip_addr" => $ipAddress
	);
echo json_encode($test);
?>
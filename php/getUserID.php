<?php
function read_file_if_exist($fp){
	if(file_exists($fp)){
		return file_get_contents($fp);
	}else{
		return "";
	}
}

$gid = read_file_if_exist($_GET['uid']);
//$gid = read_file_if_exist("../group_id/133.5.24.128");
if($gid != ""){
	//$res = array('my_gid'=>$gid);
	echo json_encode($gid);
}
?>
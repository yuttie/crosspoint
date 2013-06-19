<?php
$ip_addr = $_SERVER['REMOTE_ADDR'];
$name = $_GET['name'];
$id = $_GET['uid'];

$u_name = regist("../user_name/" . $ip_addr, $name);
$u_id = regist("../user_id/" . $ip_addr, $id);

$res = array(
	'name'=>$u_name,
	'id'=>$u_id
	);
echo json_encode($res);

// 学生IDによりグループIDを書き換える

$pre_group_id = "../pre_group_id/";
if(is_dir($pre_group_id)){
	// ディレクトリ名の指定
	$dir_name = "../pre_user_id/";
	$group_id = "../group_id/";
	// ディレクトリの存在チェック		
	if(is_dir($dir_name)){
		// ディレクトリハンドル取得
		if($dir = opendir($dir_name)){
			// ファイル情報読み込み
			while(($file = readdir($dir)) !== false){
				if(($file != ".") && ($file != "..")){
					$file_now = fopen($dir_name . $file, "r");
						$student_id = fgets($file_now);

					// 学生番号が一致する過去のIPアドレスを検索
					if(strcasecmp($u_id,$student_id) == 0){
						$pre_gid = file_get_contents($pre_group_id . $file);
						$now_gid = fopen($group_id . $ip_addr, "w");
						fwrite($now_gid, $pre_gid);
						// echo $file."\n";
						// echo $pre_gid."\n";
						fclose($now_gid);
					}

					fclose($file_now);
				}
			}
			closedir($dir);
		}
	}
}

function regist($fp,$val){
	if($val == "no_data"){
		if(file_exists($fp)){
			return file_get_contents($fp);
		}else{
			return $val;
		}
	}else{
		$handle = fopen($fp, "w");
		fwrite($handle, $val);
		fclose($handle);
		return $val;
	}
}
?>
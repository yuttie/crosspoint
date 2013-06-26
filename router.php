<?php
if (preg_match('/(?:(?:slave|0626-61E61247-B9AD-43D5-8360-23584D0C904F|question|slide|teaching_assistant|display_all)\.html|common\.css|jquery-1\.9\.0\.js|Slides0626\/.*\.jpg|php\/getId\.php|php\/getUserID\.php\?uid=\.\.\/group_id\/.*)$/', $_SERVER["REQUEST_URI"])) {
    return false;
} else {
    echo "<h1>見せられないよ＞＜！</h1>";
}
?>

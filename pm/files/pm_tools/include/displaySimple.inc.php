<?php

/*
$dataArray = array (
	'title' => 'page title',
	'content' => 'content of the page',
);
*/

?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr-FR" lang="fr-FR">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title><?php print (htmlentities($dataArray['title'], ENT_QUOTES)); ?></title>
	<?php if (array_key_exists('header',$dataArray)) print ($dataArray['header']); ?>
</head>
<body>
<?php print ($dataArray['content']); ?>
</body>
</html>

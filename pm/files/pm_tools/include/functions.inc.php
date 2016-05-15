<?php

/**
 * Log an error with additionnal debug
 *
 * @param	string	$message
 * @return	void
 */
function myLog($message = '') {

	$backtrace = debug_backtrace();
	$callFile = basename($backtrace[0]['file']);
	$callLine = $backtrace[0]['line'];

/*
	error_log('myLog() called @ ' . $callFile . ':' . $callLine . ' - ' . $message . chr(10)
		. '"QUERY_STRING": ' . $_SERVER['QUERY_STRING'] . chr(10)
		. '"POST": ' . print_r($_POST, true));
*/

	error_log('myLog() called @ ' . $callFile . ':' . $callLine . ' - ' . $message . ' - '
		. '"QUERY_STRING": http://' . $_SERVER['SERVER_NAME'] . $_SERVER['REQUEST_URI'] . ' - '
		. '"REMOTE_ADDR": ' . $_SERVER['REMOTE_ADDR'] . ' (' . gethostbyaddr($_SERVER['REMOTE_ADDR']) . ')' . ' - '
		. '"HTTP_REFERER": ' . @$_SERVER['HTTP_REFERER']);

}


/**
 * Execute a MySQL query
 *
 * @param	array		$dsn
 * @param	string	$query
 * @return	void	FALSE / array
 */
function myQuery($dsn, $query) {

	require_once('DB.php');

	$db =& DB::connect($dsn['DB_dsn'], $dsn['DB_options']);

//	if (PEAR::isError($db)) {
	if (DB::isError($db)) {
		myLog($db->getMessage() . $db->getUserInfo());
		return false;
	}

	$db->setFetchMode(DB_FETCHMODE_ASSOC);

	// always set utf8
	$result = $db->query('SET NAMES utf8;');
	if (DB::isError($result)) {
		myLog('Query error:' . $result->getMessage());
		return false;
	}

//	$result = $db->query($query);
	$result = $db->getAll($query);
	if (DB::isError($result)) {
		myLog('Query error: "' . $query . '" -> ' . $result->getMessage());
		return false;
	}

	$db->disconnect();
	return $result;

}


/**
 * Delete a folder and all its content
 *
 * @param	string	$dir
 * @return	bool	
 */
function deltree($dir) {
	if(! empty($dir) && is_dir($dir)) {
		$dir = (substr($dir, -1) != '/')? $dir . '/' : $dir;
		$openDir = opendir($dir);
		while($file = readdir($openDir)) {
			if(! in_array($file, array('.', '..'))) {
				if(! is_dir($dir.$file)) {
					unlink($dir . $file);
				} else {
					deltree($dir . $file);
				}
			}
		}
		closedir($openDir);
		rmdir($dir);
	}
}


function isHumanReadableDomain($domain) {
  $domain_regexp = '/^.*(([A-Za-z0-9]|[A-Za-z0-9][-A-Za-z0-9]*[A-Za-z0-9])\.)+('
                . 'ad|ae|aero|af|ag|ai|al|am|an|ao|aq|ar|arpa|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|'
                . 'bi|biz|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|com|'
                . 'coop|cr|cs|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|edu|ee|eg|eh|er|es|et|eu|fi|fj|fk|'
                . 'fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gov|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|'
                . 'hu|id|ie|il|in|info|int|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|'
                . 'lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mil|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|'
                . 'museum|mv|mw|mx|my|mz|na|name|nc|ne|net|nf|ng|ni|nl|no|np|nr|nt|nu|nz|om|org|pa|pe|'
                . 'pf|pg|ph|pk|pl|pm|pn|pr|pro|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk'
                . '|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug'
                . '|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)'
                . '$/';

  return is_string($domain) && preg_match($domain_regexp, $domain);
}


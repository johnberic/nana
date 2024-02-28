<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', '1');

$DB_host = "198.251.88.24";
$DB_user = "vpnskyzo_teamwork";
$DB_pass = "jYWJ9l9nb9yp";
$DB_name = "vpnskyzo_teamwork";

$mysqli = new MySQLi($DB_host,$DB_user,$DB_pass,$DB_name);
if ($mysqli->connect_error) {
    die('Error : ('. $mysqli->connect_errno .') '. $mysqli->connect_error);
}

if(isset($_GET['key']) && !empty($_GET['key'])){
    
    $key = $_GET['key'];
    
    
  function encrypt_key($paswd)
	{
	  $mykey=getEncryptKey();
	  $encryptedPassword=encryptPaswd($paswd,$mykey);
	  return $encryptedPassword;
	}
	 
	// function to get the decrypted user password
	function decrypt_key($paswd)
	{
	  $mykey=getEncryptKey();
	  $decryptedPassword=decryptPaswd($paswd,$mykey);
	  return $decryptedPassword;
	}
	 
	function getEncryptKey()
	{
		$secret_key = md5('eugcar');
		$secret_iv = md5('sanchez');
		$keys = $secret_key . $secret_iv;
		return encryptor('encrypt', $keys);
	}
	function encryptPaswd($string, $key)
	{
	  $result = '';
	  for($i=0; $i<strlen ($string); $i++)
	  {
		$char = substr($string, $i, 1);
		$keychar = substr($key, ($i % strlen($key))-1, 1);
		$char = chr(ord($char)+ord($keychar));
		$result.=$char;
	  }
		return base64_encode($result);
	}
	 
	function decryptPaswd($string, $key)
	{
	  $result = '';
	  $string = base64_decode($string);
	  for($i=0; $i<strlen($string); $i++)
	  {
		$char = substr($string, $i, 1);
		$keychar = substr($key, ($i % strlen($key))-1, 1);
		$char = chr(ord($char)-ord($keychar));
		$result.=$char;
	  }
	 
		return $result;
	}
	
	function encryptor($action, $string) {
		$output = false;

		$encrypt_method = "AES-256-CBC";
		//pls set your unique hashing key
		$secret_key = md5('eugcar sanchez');
		$secret_iv = md5('sanchez eugcar');

		// hash
		$key = hash('sha256', $secret_key);
		
		// iv - encrypt method AES-256-CBC expects 16 bytes - else you will get a warning
		$iv = substr(hash('sha256', $secret_iv), 0, 16);

		//do the encyption given text/string/number
		if( $action == 'encrypt' ) {
			$output = openssl_encrypt($string, $encrypt_method, $key, 0, $iv);
			$output = base64_encode($output);
		}
		else if( $action == 'decrypt' ){
			//decrypt the given text/string/number
			$output = openssl_decrypt(base64_decode($string), $encrypt_method, $key, 0, $iv);
		}

		return $output;
	}



    
    
    if($key == 'Tknetwork') {
      
      //  $query = $db->sql_query("SELECT user_name, user_pass FROM users WHERE private_duration > 0 AND is_freeze = 0 ORDER by user_id DESC");
      //  $query = $db->sql_query("SELECT user_name, user_pass FROM users WHERE is_freeze=1 AND duration <= 0 AND private_duration <= 0 AND is_active=0 AND status='suspended ORDER by user_id DESC");
 $data = '';
$premium = "duration > 0 AND is_freeze = 0 AND status='live'";
$vip = "is_freeze = 0 AND vip_duration > 0 AND status='live'";
$private = "is_freeze = 0 AND private_duration > 0 AND status='live'";


    $query = $mysqli->query("SELECT * FROM users
WHERE ".$premium." OR ".$private." ORDER by user_id DESC");
if($query->num_rows > 0)
{
	while($row = $query->fetch_assoc())
	{
	    	$data .= '';
        	$username = $row['user_name'];
        	$user_pass = decrypt_key($row['user_pass']);
        	$user_pass = encryptor('decrypt',$user_pass);
        	$date = date("Y-m-d", strtotime("+ 30 days"));
        	$data .= '/usr/sbin/useradd -p $(openssl passwd -1 '.$user_pass.') -s /bin/false -M '.$username.' &> /dev/null;'.PHP_EOL;
	    
	    
	
	}
}
        echo $data ;
    }else{
        echo 'Invalid Key!';
    }
}else{
    echo 'Invalid Key!';
}
?>
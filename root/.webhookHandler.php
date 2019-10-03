#!/usr/bin/env php
<?php
// GitHub Webhook Secret.
// Keep it the same with the 'Secret' field on your Webhooks / Manage webhook page of your respostory.
$secret = "cY1fehvt/ptYjLt3L39Q9gj+QbY=";

// Headers deliveried from GitHub
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE'];

if ($signature) {
  $hash = "sha1=".hash_hmac('sha1', file_get_contents("php://input"), $secret);
  if (strcmp($signature, $hash) == 0) {
    //echo shell_exec("cd {$path} && /usr/bin/git reset --hard origin/master && /usr/bin/git clean -f && /usr/bin/git pull 2>&1");
    echo shell_exec('echo "the function is being called"');
    exit();
  }
}
echo shell_exec('echo "the function ran, but didnt match the if condition"');
http_response_code(404);

?>
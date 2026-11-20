<?php
/**
 * Plugin Name: Docker mail sender
 * Description: Gives wp_mail() a valid sender on localhost so mail reaches Mailpit.
 *
 * WordPress builds the default From address from the site host, which is
 * wordpress@localhost here. PHPMailer rejects that address ("Invalid
 * address: (From)"), so wp_mail() fails before Mailpit ever sees the
 * message. Swap it for a valid address on the reserved .test TLD; a From set
 * by a plugin or theme is left alone.
 */

add_filter(
	'wp_mail_from',
	static function ( $from ) {
		return is_email( $from ) ? $from : 'wordpress@localhost.test';
	}
);

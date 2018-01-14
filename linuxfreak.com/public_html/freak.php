<html>
	<body>
		Welcome <?php echo $_POST["firstname"]; ?><br>
		Your email address is: <?php echo $_POST["email"]; ?>

		<?php
		$servername = "localhost";
		$username = "root";
		$password = "password";
		$dbname = "cust_info";
		$myDate = echo date('Y-m-d');

		// Create connection
		$conn = new mysqli($servername, $username, $password, $dbname);
		// Check connection
		if ($conn->connect_error) {
		    die("Connection failed: " . $conn->connect_error);
		}
			$sql = "INSERT INTO info (firstname, lastname, email, date)
			VALUES ('$firstname', '$lastname', '$email', '$myDate' )";

			if ($conn->query($sql) === TRUE) {
			    echo "New record created successfully";
			} else {
			    echo "Error: " . $sql . "<br>" . $conn->error;
			}
		$conn->close();
		?>
	</body>
</html>

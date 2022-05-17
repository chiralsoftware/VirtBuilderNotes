# Programmatic control over GPIO pins on the Jetson

There are many guides out there that give bits and pieces of
information about how to control the GPIO output on the Jetson but
none give a mapping between the physical pin number and the Broadcom
or BCM channel numbers.

# Pin mappings

The Jetson TX1 has a connector block called the J21 header. However
the Python GPIO library needs to reference pins not by their physical
pin number, but using a mapping to channel number by either BCM or
Broadcom standards.

The physical pin 1 on the TX1 is indicated by a triangle. 

Here is a table mapping BCM and Broadcom channel numbers to physical
pin numbers. The channel numbers were found in the file
`/usr/lib/python3/dist-packages/Jetson/GPIO/gpio_pin_data.py`.

| Physical pin number | Broadcom channel | BCM channel | Sysfs GPIO | Purpose       |
|---------------------|------------------|-------------|------------|---------------|
| 1                   |                  |             |            | 3.3 VDC power |
| 2                   |                  |             |            | 5.0 VDC power |
| 3                   |                  |             |            | SDA1          |
| 4                   |                  |             |            | 5.0 VDC power |
| 5                   |                  |             |            | SCL1          |
| 6                   |                  |             |            | GND           |
| 7                   | 7                | 4           | gpio216    | GPIO_GCLK     |
| 8                   |                  |             |            | TXD0          |
| 9                   |                  |             |            | GND           |
| 10                  |                  |             |            | RXD0          |
| 11                  | 11               | 17          | gpio162    | GPIO_GEN0     |
| 12                  | 12               | 18          | gpio11     | GPIO_GEN1     |
| 13                  | 13               | 27          | gpio38     | GPIO_GEN2     |
| 14                  |                  |             |            | GND           |
| 15                  |                  |             | gpio511    | GPIO_GEN3     |
| 16                  | 16               | 23          | gpio37     | GPIO_GEN4     |
| 17                  |                  |             |            | 3.3 VDC power |
| 18                  | 18               | 24          | gpio184    | GPIO_GEN5     |
| 19                  | 19               | 10          | gpio16     | SPI_MOSI      |
| 20                  |                  |             |            | GND           |
| 21                  | 21               | 9           | gpio17     | SPI_MISO      |
| 22                  |                  |             | gpio510    | GPIO_GEN6     |
| 23                  | 23               | 11          | gpio18     | SPI_SCLK      |
| 24                  | 24               | 8           | gpio19     | SPI_CE0_N     |
| 25                  |                  |             |            | GND           |
| 26                  | 26               | 7           | gpio20     | SPI_CE1_N     |
| 27                  |                  |             |            | ID_SDA        |
| 28                  |                  |             |            | ID_SCL        |
| 29                  | 29               | 5           | gpio219    | GPIO5         |
| 30                  |                  |             |            | GND           |
| 31                  | 31               | 6           | gpio186    | GPIO6         |
| 32                  | 32               | 12          | gpio36     | GPIO12        |
| 33                  | 33               | 13          | gpio63     | GPIO13        |
| 34                  |                  |             |            | GND           |
| 35                  | 35               | 19          | gpio8      | GPIO19        |
| 36                  | 36               | 16          | gpio163    | GPIO16        |
| 37                  | 37               | 26          | gpio187    | GPIO26        |
| 38                  | 38               | 20          | gpio9      | GPIO20        |
| 39                  |                  |             |            | GND           |
| 40                  | 40               | 21          | gpio10     | GPIO21        |


# Access in Python

We will toggle phyiscal pin 37, which is BCM channel 26 according to
the table above.

    import Jetson.GPIO as GPIO
    GPIO.setmode(GPIO.BCM)
	GPIO.setup(26, GPIO.OUT)
	GPIO.output(26, GPIO.HIGH)
	print("pin 37 set HIGH")
	sleep(10)

	GPIO.output(26, GPIO.LOW)
	print("pin 37 set LOW")

	GPIO.cleanup()
	print("i'm done")

This will result in the voltage going to 3.3V for 10 seconds, and then
returning to ground. This will be easy to observe with a voltmeter on
physical pins 37 and 39, the bottom two pins furthest to the
right. Now, that can be linked to a transistor to control an LED or
other devices.

[![Build status](https://github.com/godunko/robo-bdc/actions/workflows/alire.yml/badge.svg)](https://github.com/godunko/robo-bdc/actions/workflows/alire.yml)

# **RoboBDC** - Brushed DC Motors Controller

Many robots, especially legged robots, require the control of numerous servomotors.
While inexpensive PWM-controlled servo motors are commonly used, they lack feedback mechanisms, making precise control difficult.
These basic servos are adequate for beginners, but their limitations in performance restrict the development of more advanced and complex robotic models.

**RoboBDC** is designed to advance the robotics hobby by offering a sophisticated controller for multiple servo motors.
It repurposes essential components of widely used PWM-controlled servo motors, such as DC motors, gear assemblies, and resistive position sensors.
The system is powered by an affordable yet capable Blackpill STM32F401 microcontroller, combined with A4950 motor drivers.
This setup provides hobbyists with a cost-effective solution to build more advanced robotic systems without needing expensive or specialized hardware.

## Hardware

 * WeAct Blackpill STM32F401 (or [STM32F411 25MHz HSE](https://aliexpress.ru/item/1005001456186625.html)) Development Board
 * 2x[A4950](https://aliexpress.ru/item/1005004255910206.html) Dual Motor Drive Module

## Current state of development

Simplest position control algorithm has been implemented to prove hardware setup.

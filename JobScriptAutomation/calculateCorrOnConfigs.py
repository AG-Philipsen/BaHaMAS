#!/bin/python

import os
import subprocess
import sys
currentDirectory = os.getcwd()

ns = 16
nt = 32
kappa = 0.1000
beta = 5.8698
#mu = 0.523598775598299
mu = 0.00000
corrDir = 0
invPerConf = 8

import random
import re

def getRandomNumberTemporal( ):
	return int( random.random()*nt )

def getRandomNumberSpatial( ):
	return int( random.random()*ns )

def checkIfFileIsValid( fileIn ):
	sourcefile = re.compile("^conf.(\d+)$")

	m = sourcefile.match( fileIn )
	if m:
		return True
	else:
		return False

def getConf( fileIn ):
	corrfile = re.compile("conf.(\d+)")
	m = corrfile.match(fileIn)
	if m:
		return m.group(1)
	else:
		print "file is not a source file!"
		return -1

def getExistInv( confNum ):
	currentDirectory = os.getcwd()
	corrfile = re.compile("conf.{0}_(\d+)_(\d+)_(\d+)_(\d+)_corr".format(confNum))
	numExistInv = 0
	x = []
	y = []
	z = []
	t = []

	for curFile in os.listdir(currentDirectory):
		m = corrfile.match(curFile)
		if m:
			numExistInv += 1
			x.append(m.group(1))
			y.append(m.group(2))
			z.append(m.group(3))
			t.append(m.group(4))

	return numExistInv, x, y, z, t

def getDataFileNamePostfix_option( x, y, z, t ):
	return "--ferm_obs_corr_postfix=_{0}_{1}_{2}_{3}_corr".format(x,y,z,t)

x = []
y = []
z = []
t = []
numExistInv = 0

for sourcefile in os.listdir(currentDirectory):
	if checkIfFileIsValid( sourcefile ):
		existInv = getExistInv(getConf(sourcefile))
		numExistInv = existInv[0]
		x[:] = existInv[1]
		y[:] = existInv[2]
		z[:] = existInv[3]
		t[:] = existInv[4]

		if numExistInv < invPerConf:
			for count in range(numExistInv, invPerConf):
				while True:
					tmp = getRandomNumberSpatial()
					if not ( tmp in x ) :
						x.append(tmp)
						break
				while True:
					tmp = getRandomNumberSpatial()
					if not ( tmp in y ) :
						y.append(tmp)
						break
				while True:
					tmp = getRandomNumberSpatial()
					if not ( tmp in z ) :
						z.append(tmp)
						break
				while True:
					tmp = getRandomNumberTemporal()
					if not ( tmp in t ) :
						t.append(tmp)
						break
				xTmp = getRandomNumberSpatial()
				yTmp = getRandomNumberSpatial()
				zTmp = getRandomNumberSpatial()
				tTmp = getRandomNumberTemporal()

				while (xTmp in x) and (yTmp in y) and (zTmp in z) and (tTmp in t):
					xTmp = getRandomNumberSpatial()
					yTmp = getRandomNumberSpatial()
					zTmp = getRandomNumberSpatial()
					tTmp = getRandomNumberTemporal()
				x.append(xTmp)
				y.append(yTmp)
				z.append(zTmp)
				t.append(tTmp)

				command = "time ./inverter --sourcefile={0} --use_cpu=false --startcondition=continue --log-level=info --ns={1} --nt={2} --source_x={3} --source_y={4} --source_z={5} --source_t={6} {7} --beta={8} --kappa={9} --corr_dir={10} {11} --solver=cg --cgmax=30000 --cg_iteration_block_size=50 --theta_fermion_temporal=1".format(sourcefile, ns, nt, x[count], y[count], z[count], t[count], getDataFileNamePostfix_option(x[count], y[count], z[count], t[count]), beta, kappa, corrDir, sys.argv[1] )
				print command

				output = subprocess.check_output( command, shell=True )
				print output
		else:
			print "Already {0} inversions for conf.{1}".format(numExistInv, getConf(sourcefile))

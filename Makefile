# Mengjuei Hsieh, University of California Irvine

all:
	xcodebuild

clean:
	xcodebuild clean; rm -fr build \
	MacBlueTelnet.xcodeproj/$(USER).mode1 \
	MacBlueTelnet.xcodeproj/$(USER).mode1v3 \
	MacBlueTelnet.xcodeproj/$(USER).pbxuser

install: all
	cp -pr build/Release/Dort.app /Applications/

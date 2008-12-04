# Mengjuei Hsieh, University of California Irvine

all:
	xcodebuild

clean:
	xcodebuild clean; rm -fr build \
	MacBlueTelnet.xcodeproj/$(USER).mode1 \
	MacBlueTelnet.xcodeproj/$(USER).mode1v3 \
	MacBlueTelnet.xcodeproj/$(USER).pbxuser

install: all
	rm -r /Applications/Dort.app; mv build/Release/Dort.app /Applications/

release: all
	hdiutil create -srcfolder build/Release -volname "Dort 1.1" build/Dort1.1.dmg; \
	hdiutil internet-enable -yes build/Dort1.1.dmg

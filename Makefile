.PHONY: get analysis test run clean

get:
	flutter pub get

analysis:
	flutter analyze

test:
	flutter test

run:
	flutter run

clean:
	flutter clean
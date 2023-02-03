Archive Mailchimp Invoice
=========================

Saves given month’s invoice (defaults to this month) from Mailchimp to a PDF file named after order number, year and month like this “`ORDER_NO YEAR-MONTH.pdf`”.

This script navigates through Mailchimp website on your behalf to download given month’s invoice. You can configure the script by environment variables. You can run the script directly on your system, or you can use provided Docker Compose configuration.

This script requires that you use [two-factor authentication][mailchimp-2fa].

[mailchimp-2fa]: https://eepurl.com/dyimGz

## Direct Execution

### System Requirements

* [Ruby][ruby]
* [Bundler][bundler]
* [Selenium WebDriver browser driver][selenium-drivers]

Selenium WebDriver is highly flexible system which covers use cases from simply controlling one browser on your system to dynamically scalable multi-environment multi-browser test farms. If you do not want to dive into its intricacies, just install [Mozilla Firefox][firefox] and [geckodriver][] on your system.

[firefox]: https://www.mozilla.org/en-US/firefox/new/
[geckodriver]: https://github.com/mozilla/geckodriver/releases
[ruby]: https://www.ruby-lang.org
[bundler]: https://bundler.io
[selenium-drivers]: https://www.selenium.dev/documentation/webdriver/getting_started/install_drivers/

### Usage

The following command contains sensitive information. Make sure that you specify your credentials (especially password and two-factor authentication secret) securely. Many shells store executed commands in history which is a typical target when an attacker breaches your system. Many shells also provide a way to signal you do not want your command stored in history (for example many GNU Bash distributions ignore commands prefixed by space by predefining [`HISTCONTROL` environment variable][bash-histcontrol]).

    env \
      MAILCHIMP_USERNAME='Admin' \
      MAILCHIMP_PASSWORD='V3rySecr37' \
      MAILCHIMP_2FA_SECRET='XXXXXXXXXXXXXXXX' \
      WEBDRIVER_BROWSER=firefox \
      ./archive-mailchimp-invoice.rb

The script recognizes one argument: a month specified in ISO 8601 YYYY-MM format (for example `2023-01`).

The following invocation saves your invoice from January, 2023 (given all environment variable are set appropriately):

    ./archive-mailchimp-invoice.rb 2023-01

[bash-histcontrol]: https://www.gnu.org/software/bash/manual/bash.html#index-HISTCONTROL

## Containers via Compose

### System Requirements

* [Docker Compose][docker-compose] or other tool implementing [Compose Specification][compose-spec]

[compose-spec]: https://compose-spec.io
[docker-compose]: https://docs.docker.com/compose/

### Setup

The following file contains sensitive information. Make sure that you specify your credentials (especially password and two-factor authentication secret) securely. You can exclude the file from backups, limit access only to yourself, encrypt the volume where you store it, etc.

Create `.env` file with content like this:

    MAILCHIMP_USERNAME=Admin
    MAILCHIMP_PASSWORD=V3rySecr37
    MAILCHIMP_2FA_SECRET=XXXXXXXXXXXXXXXX

### Usage

    docker compose up --abort-on-container-exit
    docker compose down

The script executed via Docker Compose downloads this month’s invoice. To download an invoice from different month, add new environment variable `MAILCHIMP_INVOICE_DATE` to `.env` file. Set it to month specified in ISO 8601 YYYY-MM format (for example `2023-01`).

## Environment Variables

**MAILCHIMP_2FA_SECRET**, **MAILCHIMP_2FA_SECRET_FILE**  
Required. Secret to generate one-time password for two-factor authentication. If you want to avoid specifying the secret directly as environment variable, you can store it in file and use `_FILE` suffix to source the secret from the file.

**MAILCHIMP_INVOICE_DATE**  
Optional. Month specified in ISO 8601 YYYY-MM format (for example `2023-01`). Override default invoice month (this month) if no command-line argument is passed.

**MAILCHIMP_PASSWORD**, **MAILCHIMP_PASSWORD_FILE**  
Required. Authentication password. If you want to avoid specifying the password directly as environment variable, you can store it in file and use `_FILE` suffix to source the password from the file.

**MAILCHIMP_USERNAME**, **MAILCHIMP_USERNAME_FILE**  
Required. Authentication username. If you want to avoid specifying the username directly as environment variable, you can store it in file and use `_FILE` suffix to source the username from the file.

**WEBDRIVER_BROWSER**  
Required. Browser to use. One of `chrome`, `internet_explorer`, `ie`, `safari`, `firefox`, `ff` or `edge`.

**WEBDRIVER_HEADLESS**  
Optional. Headless mode if specified (even empty).

**WEBDRIVER_REMOTE_URL**  
Optional. Remote WebDriver API endpoint.

## Frequently Asked Questions

### Where can I find two-factor authentication secret?

When you [set up two-factor authentication][mailchimp-2fa], Mailchimp shows you a QR code to scan with authenticator app which can generate one-time passwords for you. That page with QR code contains the secret we are looking for. If you go to that page again, you can still find the secret there. Just go to *Profile*, then *Settings* → *Security*, and click on “*Configure Authenticator*”. The pop-up dialog contains the secret which you can use as 
 `MAILCHIMP_2FA_SECRET` environment variable.

## License

© 2023 Filip Zrůst

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but *without any warranty*; without even the implied warranty of *merchantability* or *fitness for a particular purpose*. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see [https://www.gnu.org/licenses/][gnu-licenses].

[gnu-licenses]: https://www.gnu.org/licenses/

fx_version   'cerulean'
lua54        'yes'
game         'gta5'

name         'azakit_heneggcollecting'
version      '1.1.0'
author       'Azakit'
description  'Collecting eggs from hens'

client_scripts {
    'config.lua',
	"locales/*",
    'client/*'
}

server_scripts {
	"locales/*",
	'config.lua',
    'server/*'
}


shared_scripts {
    '@ox_lib/init.lua',
}

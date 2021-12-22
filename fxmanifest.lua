fx_version 'cerulean'
games {'gta5'}

author 'Sonoran Software Systems'
description 'Sonoran CAD FiveM Integration'
version '3.0.0-dev'

server_scripts {
    'config.lua',
    'core/http.js',
    'core/console.lua',
    'core/sif.lua',
    'core/managers/shared/*.lua',
    'core/managers/server/*.lua',
    'plugins/**/config_*.lua',
    'plugins/**/sv_*.lua'
}

client_scripts {
    'core/sif_client.lua',
    'core/managers/shared/*.lua',
    'core/managers/client/*.lua',
    'plugins/**/config_*.lua',
    'plugins/**/cl_*.lua'
}
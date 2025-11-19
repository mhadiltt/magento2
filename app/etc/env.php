<?php
return [
    'backend' => [
        'frontName' => 'admin_fv4qub'
    ],
    'cache' => [
        'graphql' => [
            'id_salt' => 'IDfHFrbGAK2hNRj1NM9HQyWBz1MRgf4l'
        ],
        'frontend' => [
            'default' => [
                'id_prefix' => '176_'
            ],
            'page_cache' => [
                'id_prefix' => '176_'
            ]
        ],
        'allow_parallel_generation' => false
    ],
    'remote_storage' => [
        'driver' => 'file'
    ],
    'queue' => [
        'consumers_wait_for_messages' => 1
    ],
    'crypt' => [
        'key' => '037b072b1aa8104000f63cd4fc0f5425'
    ],
    'db' => [
        'table_prefix' => '',
        'connection' => [
            'default' => [
                'host' => '192.168.68.136:30306',
                'dbname' => 'pipe',
                'username' => 'pipe',
                'password' => '1234',
                'model' => 'mysql4',
                'engine' => 'innodb',
                'initStatements' => 'SET NAMES utf8;',
                'active' => '1',
                'driver_options' => [
                    1014 => false
                ]
            ]
        ]
    ],
    'resource' => [
        'default_setup' => [
            'connection' => 'default'
        ]
    ],
    'x-frame-options' => 'SAMEORIGIN',
    'MAGE_MODE' => 'developer',
    'session' => [
        'save' => 'files'
    ],
    'lock' => [
        'provider' => 'db'
    ],
    'directories' => [
        'document_root_is_pub' => true
    ],
    'cache_types' => [
        'config' => 1,
        'layout' => 1,
        'block_html' => 1,
        'collections' => 1,
        'reflection' => 1,
        'db_ddl' => 1,
        'compiled_config' => 1,
        'eav' => 1,
        'customer_notification' => 1,
        'config_integration' => 1,
        'config_integration_api' => 1,
        'full_page' => 1,
        'config_webservice' => 1,
        'translate' => 1
    ],
    'downloadable_domains' => [
        'pipe.test'
    ],
    'install' => [
        'date' => 'Fri, 31 Oct 2025 13:43:06 +0000'
    ]
];

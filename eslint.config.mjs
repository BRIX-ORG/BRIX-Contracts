import { defineConfig, globalIgnores } from 'eslint/config';
import prettier from 'eslint-config-prettier';
import prettierPlugin from 'eslint-plugin-prettier';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';

const eslintConfig = defineConfig([
    prettier,
    {
        files: ['**/*.ts', '**/*.mts', '**/*.cts'],
        languageOptions: {
            parser: tsParser,
        },
        plugins: {
            prettier: prettierPlugin,
            '@typescript-eslint': tsPlugin,
        },
        rules: {
            'prettier/prettier': 'warn',
            '@typescript-eslint/no-unused-vars': 'warn',
        },
    },
    {
        files: ['**/*.js', '**/*.mjs', '**/*.cjs'],
        plugins: {
            prettier: prettierPlugin,
        },
        rules: {
            'prettier/prettier': 'warn',
        },
    },
    globalIgnores([
        'node_modules/**',
        'artifacts/**',
        'cache/**',
        'typechain-types/**',
        'coverage/**',
        '.vscode/**',
        '.agent/**',
    ]),
]);

export default eslintConfig;

#include "StructureVariable.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Calcula um HashCode com base em uma string
unsigned int hashfunction(char *key)
{
    unsigned long int value = 0;

    for (int i = 0; i < strlen(key); ++i) {
        value = value * 37 + key[i];
    }

    return value % SIZE;
}

// Aloca um struct HashTable e coloca NULL em todas as posições
hashtable* build_hash_table()
{
    hashtable* ht = malloc(sizeof(hashtable));

    ht->items = malloc(sizeof(node*) * SIZE);

    for(int i = 0; i < SIZE; i++) ht->items[i] = NULL;

    return ht;
}

// Aloca um struct Node (par key~value)
node* build_pair(char* key, double value)
{
    node* n = malloc(sizeof(node));
    
    n->key = malloc(strlen(key) + 1);
    strcpy(n->key, key);

    n->value = value;

    n->next = NULL;

    return n;
}

// Adiciona (ou atualiza, se a chave já existir) um nó
void put_key_value_ht(hashtable* ht, char* key, double value)
{
    unsigned int index = hashfunction(key);

    node* item_slot = ht->items[index];

    if(item_slot == NULL)
    {
        ht->items[index] = build_pair(key, value);
        return;
    }

    node* prev;

    while(item_slot != NULL)
    {
        if(strcmp(item_slot->key, key) == 0)
        {
            item_slot->value = value;
            return;
        }

        prev = item_slot;
        item_slot = item_slot->next;
    }

    prev->next = build_pair(key, value);
}

// Obter um nó pela chave
node* get_value_ht(hashtable* ht, char* key)
{
    unsigned int index = hashfunction(key);

    node* item_slot = ht->items[index];

    if(item_slot == NULL)
        return NULL;

    while(item_slot != NULL)
    {
        if(strcmp(item_slot->key, key) == 0)
            return build_pair(item_slot->key, item_slot->value);

        item_slot = item_slot->next;
    }

    return NULL;
}

// Printa na tela todos os dados da HashTable
void show_ht(hashtable* ht)
{
    for(int i = 0; i < SIZE; i++){
        node* item_slot = ht->items[i];

        if (item_slot != NULL)
        {
            printf("ITEM #%d:\t", i);
        
            while(item_slot != NULL)
            {
                printf("(%s, %f), ", item_slot->key, item_slot->value);
                item_slot = item_slot->next;
            }

            printf(";\n");
        }
    }
}
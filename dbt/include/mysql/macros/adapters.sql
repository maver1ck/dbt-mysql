{% macro ref(model_name) %}

  {% do return(builtins.ref(model_name).include(database=false)) %}

{% endmacro %}

{% macro mysql__list_schemas(database) %}
    {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
        select distinct schema_name
        from information_schema.schemata
    {%- endcall %}

    {{ return(load_result('list_schemas').table) }}
{% endmacro %}

{% macro mysql__create_schema(relation) %}
    {% call statement('create_schema') -%}
        create schema if not exists {{ relation.without_identifier().include(database=False) }}
    {%- endcall %}
{% endmacro %}

{% macro mysql__create_table_as(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  create {% if temporary: -%}temporary{%- endif %} table
    {{ relation.include(database=False, schema=(not temporary)) }}
  as (
    {{ sql }}
  );

{% endmacro %}

{% macro mysql__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  create view {{ relation.include(database=False) }} as (
    {{ sql }}
  );
{% endmacro %}

{% macro mysql__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}
    drop {{ relation.type }} if exists {{ relation.include(database=False) }} cascade
  {%- endcall %}
{% endmacro %}

{% macro mysql__drop_relation_script(relation) -%}
    {# pyodbc does not allow multiple statements #}
    begin
    drop {{ relation.type }} if exists {{ relation.include(database=False) }} cascade
    end
{% endmacro %}

{% macro mysql__rename_relation(from_relation, to_relation) -%}
  {#
    MySQL rename fails when the relation already exists, so a 2-step process is needed:
    1. Drop the existing relation
    2. Rename the new relation to existing relation
  #}
  {% call statement('drop_relation') %}
    drop {{ to_relation.type }} if exists {{ to_relation.include(database=False) }} cascade
  {% endcall %}
  {% call statement('rename_relation') %}
    rename table {{ from_relation.include(database=False) }} to {{ to_relation.include(database=False) }}
  {% endcall %}
{% endmacro %}

{% macro mysql__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}
    select
      table_catalog as "database",
      table_name as name,
      table_schema as "schema",
      case when table_type = 'BASE TABLE' then 'table'
           when table_type = 'VIEW' then 'view'
           else table_type
      end as table_type
    from information_schema.tables
    where table_schema = '{{ schema_relation.schema }}'
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}

{% macro mysql__generate_database_name(custom_database_name=none, node=none) -%}
  {% do return(None) %}
{%- endmacro %}
mod project 'project.just'

default *args:
    podman exec -it postgres \
        psql -U postgres -d postgres {{args}}

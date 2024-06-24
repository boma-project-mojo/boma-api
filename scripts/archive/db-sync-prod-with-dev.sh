read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        tmpdump=/tmp/dump.$RANDOM
		bundle exec --verbose rake db:drop db:create db:schema:load
		heroku pg:backups:capture -a boma-production
		heroku pg:backups:download -a boma-production -o $tmpdump
		pg_restore --verbose  --no-acl --no-owner --data-only -h localhost -U sig -d shambala_current_admin_prod $tmpdump
        ;;
    *)
        # do_something_else
        ;;
esac
read -r -p "Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        aws s3 sync s3://boma-production-images s3://boma-staging-images
        aws s3 sync s3://boma-staging-images ./public/
        ;;
    *)
        # do_something_else
        ;;
esac
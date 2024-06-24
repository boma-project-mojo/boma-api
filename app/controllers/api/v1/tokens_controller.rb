class Api::V1::TokensController < ApplicationController

    skip_before_action :verify_authenticity_token, :authenticate_user!

    # Index
    # 
    # Returns all tokens associated with this address.  
    def index
      @tokens = Token.where('lower(address) = ?', index_params[:address].downcase)

      if @tokens
        render json: @tokens, :each_serializer => TokenSerializer
        return
      else
        render json: {success: false} , status: :unprocessable_entity
        return
      end
    end

    # Validate
    # 
    # This method is used when tokens are being claimed either using the publisher token scanning functionality
    # or are being claimed based on a user being in the time and space of an event.  
    # 
    # The method adds valid tokens to the queue of tokens waiting to be presented to the blockchain.  
    def validate
      token = Token.new token_params

      token = set_transaction_nonce(token)

      if token.save
        # Update the address nonce stored on the organisations model
        token.organisation.update! address_nonce: token.transaction_nonce

        BomaPresentTokenWorker.perform_async(token.id)
        render json: token, :serializer => TokenSerializer
        return
      else
        render json: {success: false, errors: token.errors}, status: :unprocessable_entity
        return
      end
    end

    # Validate_other
    #
    # Checks that the token provided is present on the blockchain for this address. 
    def validate_other
      token = Token.where(token_type_id: token_params[:token_type_id]).where('lower(address) = ?', index_params[:address].downcase).first

      if token
        token_is_present = BomaTokenService.new.is_present(token)

        if token_is_present
          render json: {success: true, token_status: token_is_present}
          return
        else
          render json: {success: false, token_status: false}
          return
        end
      else
        render json: {success: false, token_status: false}
      end
    end

    # Redeem
    #
    # handles the client side request sent via the claim_token methods in the TokensController.  
    # the method associates a token with a wallet address and adds it to the queue for mining.
    def redeem
      @token = Token.find_by_token_hash(redeem_params_tokens[:token_hash])

      if(@token)
        if(@token.aasm_state === "initialized")
          @token.address = redeem_params_tokens[:address]
          @token.aasm_state = :queued

          @token = set_transaction_nonce(@token)

          if @token.save
            # Update the address nonce stored on the organisations model
            @token.organisation.update! address_nonce: @token.transaction_nonce

            # Present the token to the blockchain
            BomaPresentTokenWorker.perform_async(@token.id)
            
            render json: {success: true}
          else
            render json: {success: false, status: :unprocessable_entity, error: "Your wallet already contains a token of this type.  "}
          end
        else
          render json: {success: false, status: :unprocessable_entity, error: "This unique code has already been redeemed. "}
        end
      else
        render json: {success: false, status: :unprocessable_entity, error: "This unique code is not valid. "}
      end
    end

    private
      def index_params
        params.permit(:address)
      end

      def token_params
        token_type = TokenType.find(params['token_type_id'])
        params[:festival_id] = params[:festival_id] ? params[:festival_id] : token_type.festival_id
        params.permit(:festival_id, :address, :token_type_id, :client_id)
      end

      def redeem_params_tokens
        params[:token_hash] = params[:nonce]
        params.permit(:token_hash, :nonce, :address)
      end

      def set_transaction_nonce token
        # Increment the transaction_nonce
        next_transaction_nonce = token.organisation.address_nonce+1

        # Set the transaction_nonce on this token to be the last nonce for this address plus one
        token.transaction_nonce = next_transaction_nonce
        token.aasm_state = :queued

        return token
      end
 end

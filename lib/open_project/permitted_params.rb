  # def placeholder_user
  #   params.require(:placeholder_user).permit(:name)
  # end

  # def station
  #   params.require(:station).permit(:name, :position)
  # end 

  module OpenProject
    class PermittedParams
      def placeholder_user
        params.require(:placeholder_user).permit(:name)
      end
  
      def station
        params.require(:station).permit(:name, :position)
      end
    end
  end 
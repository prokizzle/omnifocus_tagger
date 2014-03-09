require 'sequel'

module OmniFocusTools
  class TagConverter

    def initialize
      home_path = %x{echo $HOME}.to_s.split.first
      $db = Sequel.connect("sqlite://#{home_path}/Library/Caches/com.omnigroup.OmniFocus/OmniFocusDatabase2")
      @tasks = $db[:task]
      @contexts = $db[:context]
      @projects = $db[:projectinfo]
      # id = @projects.first[:task]
      # puts @tasks.where(persistentIdentifier: id).first[:name]
    end


    # Sets a context to a task
    # @param string name - name of the task to change
    # @param string context - fuzzy name of context to set
    #
    def change_context(name, context)
      # puts name, context, "*"
      begin
        context_id = @contexts.where(Sequel.like(:name, "#{context}")).first[:persistentIdentifier]
      rescue
        @contexts.where(Sequel.like(:name, "#{context.capitalize}%")).first[:persistentIdentifier]
      end
      @tasks.where(name: name).update(context: context_id)
    end

    # Finds all tagged tasks, detects tag content, applies contexts to tasks
    #
    def run
      print "Converting tags to contexts..."
      @tasks.where(Sequel.like(:noteXMLData, '%#%'), :dateCompleted=>nil).each do |r|
        # puts r[:name]
        tag = r[:noteXMLData].match(/<lit>#(.+)<\/lit>/)[1]
        change_context(r[:name], tag.capitalize)
        @tasks.where(name: r[:name]).update(noteXMLData: "")
        # Hr.print "="
      end
      sleep 2
      print "\rRestarting OmniFocus...         "

      %x{osascript -e 'tell application "OmniFocus" to quit'}

      %x{osascript -e 'tell application "OmniFocus" to activate'}
      sleep 2
      print "\r                               "
      # @tasks.where(Sequel.like(:noteXMLData, '%#%'), :dateCompleted=>nil).each do |r|
      #   # puts r[:name]
      #   tag = r[:noteXMLData].match(/<lit>#(.+)<\/lit>/)[1]
      #   change_context(r[:name], tag.capitalize)
      #   # Hr.print "="
      # end

    end

  end
end

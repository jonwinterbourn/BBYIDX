# Adds handling for :example => 'foo' to form fields

module ActionView
  module Helpers #:nodoc:
    class InstanceTag
      include JavaScriptHelper
      
      alias_method :tag_without_example, :tag
      alias_method :content_tag_without_example, :content_tag
      
      def tag(name, opts = nil, *args)
        extra_html = handle_example(opts)
        tag_without_example(name, opts, *args) + extra_html
      end
      
      def content_tag(name, value, opts)
        extra_html = handle_example(opts)
        content_tag_without_example(name, value, opts) + extra_html
      end
      
    private
    
      def handle_example(opts)
        example = opts.delete('example')
        if example
          cssClass = opts['class'] || ''
          exampleClass = opts.delete('example_class') || 'example ' + cssClass
          realTextClass = opts.delete('real_text_class') || 'real-text ' + cssClass
          js = "addExampleText("
          js << "$('#{escape_javascript(opts["id"])}'),"
          js << "'#{escape_javascript(example)}',"
          js << "'#{escape_javascript(exampleClass)}',"
          js << "'#{escape_javascript(realTextClass)}')"
          javascript_tag(js)
        else
          ''
        end
      end
    end
  
    module PrototypeHelper
      alias_method :remote_form_for_without_example, :remote_form_for
    
      def remote_form_for(*args, &block)
        if args.last.is_a?(Hash) && args.last[:has_example_text]
          remote_form_for_without_example(*args) do |*block_args|
            # Alas, the example text registers onsubmit handlers which need to run BEFORE the onsubmit handler
            # generated by remote_form_for that actually does the ajax call. So we rip that handler out here,
            # and tack it back on to the end later. There must be a better way, but I don't know what it is! -PPC
        
            anchor_id = "form_anchor_#{rand(10000000)}"
            concat(
              "<div id='#{anchor_id}'></div>" +
              javascript_tag("
                 form = $('#{anchor_id}').parentNode;
                 submitHandler = form.onsubmit;
                 form.onsubmit = function() { return false };"),
              binding)
        
            yield(*block_args)
        
            # Add the submit handler we ripped out above.
            concat(
              javascript_tag("Event.observe(form, 'submit', submitHandler);"),
              binding)
          end
        else
          remote_form_for_without_example(*args, &block)
        end
      end
    end
    
  end
end